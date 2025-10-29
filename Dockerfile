# 1. Start with a lean Python base image
FROM python:3.9-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy the rest of the application code
COPY . .

# 5. Expose port 3000 (matches app.py and main.tf)
EXPOSE 3000

# 6. Command to run the app using gunicorn
# This runs the 'app' object from the 'app.py' file
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:3000", "app:app"]