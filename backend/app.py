from fastapi import FastAPI 
app=FastAPI()


@app.get("/")
def home_route():
    return {"message":"this is home route"}


@app.get("/greet")
def greet_route():
    return {"data":"hello world"}