FROM python:3

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY dtr-repo-mirror.py .
COPY mirror.cfg .

CMD [ "python", "./dtr-repo-mirror.py" ]
