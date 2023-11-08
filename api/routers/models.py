from fastapi import APIRouter, HTTPException
from langchain.embeddings import HuggingFaceEmbeddings, LlamaCppEmbeddings
from langchain.llms import HuggingFacePipeline, LlamaCpp
from .utils import summarize_templates

model_infos = {
    # 'llm': {
    #     'type': 'HuggingFacePipeline',
    #     'path': '../chinese-alpaca-2-13b',
    #     'template': 'CNLlama2Template',
    #     'status': 'unloaded',
    # },
    # 'embedding': {
    #     'type': 'HuggingFaceEmbeddings',
    #     'path': '../all-MiniLM-L6-v2',
    #     'status': 'unloaded',
    # },
    'llm': {
        'type': 'LlamaCpp',
        'path': '../chinese-alpaca-2-13b/ggml-model-q4_0.gguf',
        'template': 'CNLlama2Template',
        'summarize_templates': summarize_templates['cnllama2'],
        'status': 'unloaded',
    },
    'embedding': {
        'type': 'LlamaCppEmbeddings',
        'path': '../chinese-alpaca-2-13b/ggml-model-q4_0.gguf',
        'status': 'unloaded',
    },
}
models = {}


def get_model(name):
    if name not in model_infos:
        raise HTTPException(status_code=400, detail='No such model')
    if name not in models:
        raise HTTPException(status_code=400, detail='Model unloaded')
    return model_infos[name], models[name]


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
    elif info['type'] == 'LlamaCpp':
        kwargs = {'n_ctx': 4096}
        models[name] = LlamaCpp(model_path=info['path'], **kwargs)
    elif info['type'] == 'LlamaCppEmbeddings':
        models[name] = LlamaCppEmbeddings(model_path=info['path'])
    info['status'] = 'loaded'


@router.get("/models/{name}/unload", tags=["models"], status_code=204)
def unload(name: str):
    if name in models:
        del models[name]
        model_infos[name]['status'] = 'unloaded'
