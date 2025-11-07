def test_index():
    from src.main import app
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    assert b"Hello" in response.data
