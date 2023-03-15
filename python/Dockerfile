# base image
FROM python:3.12.0a6-slim-buster

# set working directory
WORKDIR /app

# copy requirements.txt into working directory
COPY requirements.txt .

# run pip freeze
RUN pip freeze > requirements.txt

# install dependency
RUN pip install --no-cache-dir -r requirements.txt

# copy apps into working directory
COPY . .

# run command
CMD ["python", "app.py"]
