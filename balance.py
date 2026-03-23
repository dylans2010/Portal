import sys

def check_balance(filename):
    with open(filename, 'r') as f:
        content = f.read()

    stack = []
    line = 1
    col = 1
    in_string = False
    in_comment = False
    in_multiline_comment = False

    i = 0
    while i < len(content):
        c = content[i]

        if in_multiline_comment:
            if c == '*' and i+1 < len(content) and content[i+1] == '/':
                in_multiline_comment = False
                i += 1
        elif in_comment:
            if c == '\n':
                in_comment = False
        elif in_string:
            if c == '"' and content[i-1] != '\\':
                in_string = False
            elif c == '\n':
                in_string = False
        else:
            if c == '/' and i+1 < len(content) and content[i+1] == '/':
                in_comment = True
                i += 1
            elif c == '/' and i+1 < len(content) and content[i+1] == '*':
                in_multiline_comment = True
                i += 1
            elif c == '"':
                in_string = True
            elif c == '{':
                stack.append((line, col))
            elif c == '}':
                if not stack:
                    print(f"Extraneous }} at line {line}, col {col}")
                else:
                    stack.pop()

        if c == '\n':
            line += 1
            col = 1
        else:
            col += 1
        i += 1

    if stack:
        for l, c in stack:
            print(f"Unclosed {{ at line {l}, col {c}")

check_balance(sys.argv[1])
