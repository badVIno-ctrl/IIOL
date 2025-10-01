1. Получаем прогноз погоды без API и сложных настроек на Python

Мы используем сервис wttr.in — простой и мощный инструмент, который покажет погоду прямо в консоли.

Для работы с HTTP-запросом  понадобится только одна библиотека - requests. Установить её очень просто:

Bash
pip install requests

- код для получения прогноза:

Python
import requests

city = input("Введите название города: ")
url = f"https://wttr.in/{city}"

try:
    response = requests.get(url)
    print(response.text)
except Exception:
    print("Упс! Что-то пошло не так. Попробуйте позже.")

- Просто вводите нужный город, и получите подробный прогноз с температурой, осадками 

2. бесплатные API - https://github.com/public-api-lists/public-api-lists

3. Создаём QR-коды с помощью Python всего за несколько строк кода (Любой может сгенерировать свой QR-код для ссылки, текста или даже Wi-Fi данных.)

Bash
pip install qrcode pillow

- код:
import qrcode
from PIL import Image

data = input("Введите данные для QR: ")
qr = qrcode.QRCode(version=3, box_size=8, border=4)
qr.add_data(data)
qr.make(fit=True)

image = qr.make_image(fill="black", back_color="aqua")
image.save("qr_code.png")
Image.open("qr_code.png")
