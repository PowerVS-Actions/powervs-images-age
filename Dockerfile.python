FROM ubuntu:20.04

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

RUN apt-get update; apt-get -y install pwgen python3 python3-pip libpq-dev \
python-dev build-essential; pip3 install psycopg2; pip3 install pytz

WORKDIR /python

COPY ./insert.py .

ENTRYPOINT ["/usr/bin/python3", "./insert.py"]
