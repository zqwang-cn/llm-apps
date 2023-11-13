import json
from fastapi import APIRouter, HTTPException, Response
from pydantic import BaseModel
from .models import get_model

router = APIRouter()


class LlamacppGrammarData(BaseModel):
    model_name: str
    text: str


@router.post("/llamacpp-grammar/generate", tags=["llamacpp-grammar"])
async def generate(data: LlamacppGrammarData):
    info, llm = get_model(data.model_name)
    if info["type"] != "LlamaCpp":
        raise HTTPException(status_code=400, detail="Only support llamacpp models")
    if "kwargs" not in info or "grammar_path" not in info["kwargs"]:
        raise HTTPException(
            status_code=400,
            detail=f"Model {data.model_name} does not support llamacpp grammar",
        )

    result = json.loads(llm(data.text))
    content = json.dumps({"result": result}, ensure_ascii=False)
    return Response(content=content, media_type="application/json;charset=utf-8")
