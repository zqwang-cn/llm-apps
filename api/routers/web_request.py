import json
from fastapi import APIRouter, HTTPException, Response
from langchain.chains import LLMChain, LLMRequestsChain
from langchain.prompts import PromptTemplate
from pydantic import BaseModel
from .models import get_model

router = APIRouter()


class WebRequestData(BaseModel):
    model_name: str
    query: str
    url: str


@router.post("/web-request/query", tags=["web-request"])
async def query(data: WebRequestData):
    info, llm = get_model(data.model_name)
    if "web_request_template" not in info:
        raise HTTPException(
            status_code=400,
            detail=f"Model {data.model_name} does not support web request query",
        )

    template = info["web_request_template"]
    prompt = PromptTemplate(
        input_variables=["query", "requests_result"],
        template=template,
    )
    chain = LLMRequestsChain(llm_chain=LLMChain(llm=llm, prompt=prompt))
    input = {
        "query": data.query,
        "url": data.url,
    }
    result = chain(input)["output"]

    content = json.dumps({"result": result}, ensure_ascii=False)
    return Response(content=content, media_type="application/json;charset=utf-8")
