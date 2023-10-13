import json
import os
from typing import Annotated
from fastapi import APIRouter, File, Form, HTTPException, Response, UploadFile
from langchain import hub
from langchain.chains import RetrievalQA
from langchain.document_loaders import TextLoader, UnstructuredWordDocumentLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.vectorstores import Chroma
from pydantic import BaseModel
from .models import models

UPLOAD_DIR = 'upload/'
RAG_PROMPT = hub.pull("rlm/rag-prompt-llama")

qa = None

router = APIRouter()


@router.post("/doc-qa/add-doc", tags=["doc-qa"], status_code=204)
async def add_doc(
    file: Annotated[UploadFile, File],
    llm_name: Annotated[str, Form()],
    emb_name: Annotated[str, Form()],
):
    if llm_name not in models or emb_name not in models:
        raise HTTPException(status_code=400, detail="Please load models first")

    llm = models[llm_name]
    emb = models[emb_name]

    content = await file.read()
    filename = os.path.join(UPLOAD_DIR, file.filename)
    with open(filename, 'wb') as f:
        f.write(content)

    if filename.endswith('.txt'):
        loader = TextLoader(filename)
    if filename.endswith(('.doc', 'docx')):
        loader = UnstructuredWordDocumentLoader(
            filename, mode="single", strategy="fast"
        )
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=0)
    splits = text_splitter.split_documents(loader.load())
    vectorstore = Chroma.from_documents(documents=splits, embedding=emb)

    global qa
    qa = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        chain_type_kwargs={"prompt": RAG_PROMPT},
        retriever=vectorstore.as_retriever(),
    )


class Query(BaseModel):
    q: str


@router.post("/doc-qa/query", tags=["doc-qa"])
async def query(query: Query):
    if qa is None:
        raise HTTPException(status_code=400, detail="Please add doc first")

    ans = qa.run(query.q)
    content = json.dumps({"ans": ans}, ensure_ascii=False)
    return Response(content=content, media_type='application/json;charset=utf-8')
