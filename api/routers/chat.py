import json
from typing import Dict, List
from fastapi import APIRouter, Response
from pydantic import BaseModel
from .models import model_infos, models
from .utils import get_template

router = APIRouter()


class ChatData(BaseModel):
    model_name: str
    dialog: List[Dict[str, str]]


@router.post("/chat/chat", tags=["chat"])
async def chat(data: ChatData):
    template = get_template(model_infos[data.model_name]['template'])
    prompt = template.format(data.dialog)
    result = models[data.model_name](prompt)
    content = json.dumps({'result': result})
    return Response(content=content, media_type='application/json;charset=utf-8')
