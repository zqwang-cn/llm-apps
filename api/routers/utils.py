class CNLlama2Template:
    prefix = '<<SYS>>\n{system}\n<</SYS>>\n\n'
    prompt = '[INST] {query} [/INST] '
    system = 'You are a helpful assistant. 你是一个乐于助人的助手。'
    bos = '<s>'
    eos = '</s>'

    def format(self, dialog):
        system = (
            dialog.pop(0)['content'] if dialog[0]['role'] == 'system' else self.system
        )
        prefix = self.prefix.format(system=system)
        dialog[0]['content'] = prefix + dialog[0]['content']
        result = ''
        for prompt, answer in zip(dialog[0::2], dialog[1::2]):
            result += (
                self.bos
                + self.prompt.format(query=prompt['content'].strip())
                + answer['content'].strip()
                + ' '
                + self.eos
            )

        result += self.bos + self.prompt.format(query=dialog[-1]['content'].strip())
        return result


def get_template(name):
    return eval(name + '()')
