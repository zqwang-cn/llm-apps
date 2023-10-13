from fastapi import APIRouter, HTTPException
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import HuggingFacePipeline

model_infos = {
    'llm': {
        'type': 'HuggingFacePipeline',
        'path': '../chinese-alpaca-2-13b',
        'status': 'unloaded',
    },
    'embedding': {
        'type': 'HuggingFaceEmbeddings',
        'path': '../all-MiniLM-L6-v2',
        'status': 'unloaded',
    },
}
models = {}

router = APIRouter()


@router.get("/models", tags=["models"])
def list():
    return model_infos


@router.get("/models/{name}/load", tags=["models"], status_code=204)
def load(name: str):
    if name not in model_infos:
        raise HTTPException(status_code=400, detail="No such model")
    if name in models:
        return

    info = model_infos[name]
    if info['type'] == 'HuggingFacePipeline':
        model_kwargs = {'device_map': 'auto'}
        pipeline_kwargs = {'max_new_tokens': 1000}
        models[name] = HuggingFacePipeline.from_model_id(
            model_id=info['path'],
            task="text-generation",
            model_kwargs=model_kwargs,
            pipeline_kwargs=pipeline_kwargs,
        )
    elif info['type'] == 'HuggingFaceEmbeddings':
        model_kwargs = {'device': 'cuda'}
        encode_kwargs = {'normalize_embeddings': False}
        models[name] = HuggingFaceEmbeddings(
            model_name=info['path'],
            model_kwargs=model_kwargs,
            encode_kwargs=encode_kwargs,
        )
    info['status'] = 'loaded'


@router.get("/models/{name}/unload", tags=["models"], status_code=204)
def unload(name: str):
    if name in models:
        del models[name]
        model_infos[name]['status'] = 'unloaded'
