FROM python:3.6
MAINTAINER Erokhin Dmitry <derokhin@lanit.ru>
USER root
# установка нужных программ для работы
COPY *.txt /opt/
COPY *.py /opt/
COPY *.json /opt/

RUN pip install -r /opt/requirements.txt && \
    rm /opt/requirements.txt
WORKDIR /opt
VOLUME ["/opt/"]
EXPOSE 8080
ENTRYPOINT ["python", "main.py"]
