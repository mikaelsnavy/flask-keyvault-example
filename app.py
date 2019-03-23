import os, logging
from flask import Flask

from flask_keyvault import KeyVault
from flask_keyvault.exceptions import KeyVaultAuthenticationError

app = Flask(__name__)

key_vault = KeyVault()
key_vault.init_app(app)

app.config.update(
    KEYVAULT_URL = os.getenv("KEYVAULT_URL"),
    KEYVAULT_SECRETS = ["test-secret"]
)
app.logger.setLevel(logging.DEBUG)

# Attempt to get and override configuration from KeyVault
if "KEYVAULT_URL" in app.config and app.config["KEYVAULT_URL"]:
    try:
        for secret_name in app.config['KEYVAULT_SECRETS']:
            app.config[secret_name.replace("-", "_")] = key_vault.get(app.config['KEYVAULT_URL'], secret_name)
    except KeyVaultAuthenticationError as err: 
        app.logger.warning(f'Error authenticating to Azure Key Vault for setting configuration.')

@app.route('/')
def secret_test():
    return app.config['test_secret']

@app.route('/environ')
def environ_test():
    return str(os.environ)

if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0', port=80)