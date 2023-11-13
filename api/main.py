from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import (
    chat,
    doc_qa,
    jsonformer,
    llamacpp_grammar,
    models,
    sql_qa,
    summarize,
)

app = FastAPI()
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(models.router)
app.include_router(chat.router)
app.include_router(doc_qa.router)
app.include_router(summarize.router)
app.include_router(sql_qa.router)
app.include_router(jsonformer.router)
app.include_router(llamacpp_grammar.router)
