from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>Hello from Python, deployed by Jenkins and Terraform!</h1>'

if __name__ == '__main__':
    # Run on port 3000 to match the Terraform 'WEBSITES_PORT' App Setting
    app.run(host='0.0.0.0', port=3000)