import requests

def get_request_and_continue_on_failure(base_url, endpoint):
    full_url = base_url + endpoint
    response = requests.get(full_url, verify=False)
    return {
        "status_code": response.status_code,
        "json": response.json() if response.content else None
    }
