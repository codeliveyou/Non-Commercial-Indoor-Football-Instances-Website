import math

def pyramid_level(num : int) -> int:
    sqrtl = int(math.sqrt(num * 2))
    if sqrtl * (sqrtl + 1) / 2== num:
        return sqrtl
    return -1

def decode(message_file):
    with open(message_file, 'r') as file:
        lines = file.readlines()
    pyramid_level = 1
    message = []
    for line in lines:
        number, word = line.split()
        level = pyramid_level(number)
        if level != -1:
            message.append(word)
            pyramid_level += 1
    return ' '.join(message)


print(decode("input.txt"))
