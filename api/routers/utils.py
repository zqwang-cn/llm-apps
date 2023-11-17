import os
import tempfile
from langchain.document_loaders import TextLoader, UnstructuredWordDocumentLoader


UPLOAD_DIR = "upload/"


def gen_temp(filename, dir=UPLOAD_DIR):
    main, ext = os.path.splitext(filename)
    f = tempfile.NamedTemporaryFile(
        dir=dir, prefix=main + "_", suffix=ext, delete=False
    )
    return f


async def save_file(file):
    content = await file.read()
    f = gen_temp(file.filename)
    f.write(content)
    f.close()
    return f.name


async def load_doc(file):
    filename = await save_file(file)

    if filename.endswith(".txt"):
        loader = TextLoader(filename)
    elif filename.endswith((".doc", "docx")):
        loader = UnstructuredWordDocumentLoader(
            filename, mode="single", strategy="fast"
        )
    return loader.load()


class CNLlama2Template:
    prefix = "<<SYS>>\n{system}\n<</SYS>>\n\n"
    prompt = "[INST] {query} [/INST] "
    system = "You are a helpful assistant. 你是一个乐于助人的助手。"
    bos = "<s>"
    eos = "</s>"

    def format(self, dialog):
        system = (
            dialog.pop(0)["content"] if dialog[0]["role"] == "system" else self.system
        )
        prefix = self.prefix.format(system=system)
        dialog[0]["content"] = prefix + dialog[0]["content"]
        result = ""
        for prompt, answer in zip(dialog[0::2], dialog[1::2]):
            result += (
                self.bos
                + self.prompt.format(query=prompt["content"].strip())
                + answer["content"].strip()
                + " "
                + self.eos
            )

        result += self.bos + self.prompt.format(query=dialog[-1]["content"].strip())
        return result


def get_template(name):
    return eval(name + "()")


summarize_templates = {
    "cnllama2": {
        "stuff": (
            "[INST] <<SYS>>\n"
            "You are a helpful assistant. 你是一个乐于助人的助手。\n"
            "<</SYS>>\n\n"
            "请为以下文字写一段摘要:\n{text} [/INST]"
        ),
        "refine": {
            "question": (
                "[INST] <<SYS>>\n"
                "You are a helpful assistant. 你是一个乐于助人的助手。\n"
                "<</SYS>>\n\n"
                "请为以下文字写一段摘要:\n{text} [/INST]"
            ),
            "refine": (
                "[INST] <<SYS>>\n"
                "You are a helpful assistant. 你是一个乐于助人的助手。\n"
                "<</SYS>>\n\n"
                "已有一段摘要：{existing_answer}\n"
                "现在还有一些文字，（如果有需要）你可以根据它们完善现有的摘要。"
                "\n"
                "{text}\n"
                "\n"
                "如果这段文字没有用，返回原来的摘要即可。请你生成一个最终的摘要。"
                " [/INST]"
            ),
        },
    }
}

default_web_request_template = """Between >>> and <<< are the raw search result text from Internet.
Extract the answer to the question '{query}' or say "not found" if the information is not contained.
Use the format
Extracted:<answer or "not found">
>>> {requests_result} <<<
Extracted:"""
