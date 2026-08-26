FROM python:3.8-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN chmod +x reset_db.sh runapp.sh
EXPOSE 8000
CMD ["./runapp.sh"]