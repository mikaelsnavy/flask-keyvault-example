import os, logging
from flask import Flask
from flask_env import MetaFlaskEnv

from flask_keyvault import KeyVault
from flask_keyvault.exceptions import KeyVaultAuthenticationError

class Configuration(metaclass=MetaFlaskEnv):
    ENV_PREFIX = 'APP_'
    ENV_LOAD_ALL = True

app = Flask(__name__)
app.config.from_object(Configuration)

key_vault = KeyVault()
key_vault.init_app(app)
app.logger.setLevel(logging.DEBUG)

# Attempt to get and override configuration from KeyVault
print("Trying to load KV secrets...")
try:
    print("Looping through secrets...")
    for item in key_vault.list(app.config.get('KEYVAULT_URL')):
        secret_name = item.id.split("/secrets/")[-1]
        print(f'Adding {secret_name}...')
        app.config[secret_name.replace("-", "_")] = key_vault.get(app.config.get('KEYVAULT_URL'), secret_name)
except KeyVaultAuthenticationError as err: 
    app.logger.warning(f'Error authenticating to Azure Key Vault for setting configuration.')
except Exception as err:
    app.logger.warning(f'Unknown exception occured {err}.')

@app.route('/')
def secret_test():
    return app.config.get('test_secret', 'Not Set')

@app.route('/environ')
def environ_test():
    return str(os.environ)

@app.route('/config')
def config_test():
    return str(app.config)

@app.route('/config_test')
def config_test_test():
    return app.config.get('KEYVAULT_URL', 'Not Set')
    
if __name__ == '__main__':
    app.run(debug=True,host='0.0.0.0', port=80)