import os
from fastapi import APIRouter, HTTPException, UploadFile
from langchain import hub
from langchain.chains import RetrievalQA
from langchain.document_loaders import TextLoader, UnstructuredWordDocumentLoader
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import HuggingFacePipeline
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.vectorstores import Chroma

LLM_MODEL_PATH = "../chinese-alpaca-2-13b"
EMB_MODEL_PATH = "../all-MiniLM-L6-v2"
UPLOAD_DIR = 'upload/'
RAG_PROMPT = hub.pull("rlm/rag-prompt-llama")

llm = None
emb = None
qa = None

router = APIRouter()


@router.get("/doc-qa/load", tags=["doc-qa"], status_code=204)
async def load():
    global llm
    global emb
    if llm is None:
        model_kwargs = {'device_map': 'auto'}
        pipeline_kwargs = {'max_new_tokens': 1000}
        llm = HuggingFacePipeline.from_model_id(
            model_id=LLM_MODEL_PATH,
            task="text-generation",
            model_kwargs=model_kwargs,
            pipeline_kwargs=pipeline_kwargs,
        )

        model_kwargs = {'device': 'auto'}
        encode_kwargs = {'normalize_embeddings': False}
        emb = HuggingFaceEmbeddings(
            model_name=EMB_MODEL_PATH,
            model_kwargs=model_kwargs,
            encode_kwargs=encode_kwargs,
        )


@router.get("/doc-qa/unload", tags=["doc-qa"], status_code=204)
async def unload():
    global llm
    global emb
    if llm:
        del llm
        llm = None
    if emb:
        del emb
        emb = None


@router.post("/doc-qa/add-doc", tags=["doc-qa"], status_code=204)
async def add_doc(file: UploadFile):
    if llm is None:
        raise HTTPException(status_code=400, detail="Please load models first")

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


@router.get("/doc-qa/query", tags=["doc-qa"])
async def query(q: str):
    if qa is None:
        raise HTTPException(status_code=400, detail="Please add doc first")

    ans = qa.run(q)
    return {"ans": ans}
