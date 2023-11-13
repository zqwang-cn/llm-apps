import json
from typing import Any, Dict
from fastapi import APIRouter, HTTPException, Response
from jsonformer import Jsonformer
from pydantic import BaseModel
from .models import get_model

router = APIRouter()


class JsonformerData(BaseModel):
    model_name: str
    json_schema: Dict[str, Any]
    prompt: str


@router.post("/jsonformer/generate", tags=["jsonformer"])
async def generate(data: JsonformerData):
    info, llm = get_model(data.model_name)
    if info["type"] != "HuggingFacePipeline":
        raise HTTPException(
            status_code=400, detail="Only support huggingface pipeline models"
        )

    try:
        jsonformer = Jsonformer(
            model=llm.pipeline.model,
            tokenizer=llm.pipeline.tokenizer,
            json_schema=data.json_schema,
            prompt=data.prompt,
        )
        result = jsonformer()
    except:
        raise HTTPException(status_code=400, detail="Generate error")

    content = json.dumps({"result": result}, ensure_ascii=False)
    return Response(content=content, media_type="application/json;charset=utf-8")
