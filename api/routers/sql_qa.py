import json
import sqlite3
from fastapi import APIRouter, HTTPException, Response, UploadFile
from langchain.chains import create_sql_query_chain
from langchain.utilities import SQLDatabase
from langchain_experimental.sql import SQLDatabaseChain
from pydantic import BaseModel
from .models import get_model
from .utils import gen_temp, save_file


router = APIRouter()


@router.post("/sql-qa/upload", tags=["sql-qa"])
async def upload(file: UploadFile):
    if file.filename.endswith(".sql"):
        db_file = gen_temp(file.filename[:-4] + ".db")
        db_file.close()
        db_filename = db_file.name
        conn = sqlite3.connect(db_filename)
        conn.executescript((await file.read()).decode())
        conn.close()
    elif file.filename.endswith((".db", ".sqlite", ".sqlite3")):
        db_filename = await save_file(file)
    else:
        raise HTTPException(
            status_code=400, detail="Only support .sql, .db, .sqlite or .sqlite3 file"
        )

    content = json.dumps({"uri": f"sqlite:///{db_filename}"}, ensure_ascii=False)
    return Response(content=content, media_type="application/json;charset=utf-8")


class SQLQuery(BaseModel):
    model_name: str
    uri: str
    type: str
    question: str


@router.post("/sql-qa/query", tags=["sql-qa"])
async def query(query: SQLQuery):
    _, llm = get_model(query.model_name)
    db = SQLDatabase.from_uri(query.uri)

    if query.type == "sql":
        chain = create_sql_query_chain(llm, db)
        sql = chain.invoke({"question": query.question})
        result = {"result": sql}
    elif query.type == "answer":
        chain = SQLDatabaseChain.from_llm(llm, db)
        answer = chain.run(query.question)
        result = {"result": answer}
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported type {query.type}")

    content = json.dumps(result, ensure_ascii=False)
    return Response(content=content, media_type="application/json;charset=utf-8")
