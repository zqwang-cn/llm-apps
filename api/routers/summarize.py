import json
from typing import Annotated
from fastapi import APIRouter, File, Form, HTTPException, Response, UploadFile
from langchain.chains.summarize import load_summarize_chain
from langchain.prompts import PromptTemplate
from .models import get_model
from .utils import load_doc

router = APIRouter()


@router.post("/summarize/summarize", tags=["summarize"])
async def summarize(
    file: Annotated[UploadFile, File],
    model_name: Annotated[str, Form()],
    type: Annotated[str, Form()],
):
    info, llm = get_model(model_name)
    if 'summarize_templates' not in info:
        raise HTTPException(
            status_code=400,
            detail=f'Model {model_name} does not support summerize',
        )
    templates = info['summarize_templates']
    if type not in templates:
        raise HTTPException(
            status_code=400,
            detail=f'Model {model_name} does not support summerize type {type}',
        )

    if type == 'stuff':
        kwargs = {'prompt': PromptTemplate.from_template(templates['stuff'])}
    elif type == 'map_reduce':
        kwargs = {
            'map_prompt': PromptTemplate.from_template(templates['map_reduce']['map']),
            'combine_prompt': PromptTemplate.from_template(
                templates['map_reduce']['combine']
            ),
        }
    elif type == 'refine':
        kwargs = {
            'question_prompt': PromptTemplate.from_template(
                templates['refine']['question']
            ),
            'refine_prompt': PromptTemplate.from_template(
                templates['refine']['refine']
            ),
        }
    else:
        raise HTTPException(status_code=400, detail='Unsupported summarize type')

    chain = load_summarize_chain(
        llm=llm,
        chain_type=type,
        **kwargs,
    )
    docs = await load_doc(file)
    result = chain.run(docs)

    content = json.dumps({"result": result}, ensure_ascii=False)
    return Response(content=content, media_type='application/json;charset=utf-8')
