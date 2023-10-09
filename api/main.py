from fastapi import FastAPI
from .routers import doc_qa

app = FastAPI()
app.include_router(doc_qa.router)
