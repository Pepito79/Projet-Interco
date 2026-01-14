from flask import Flask, request, render_template_string
import os

app = Flask(__name__)

HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>FAI - Inscription FTP</title>
    <style>
        body { font-family: sans-serif; background: #f4f4f4; display: flex; justify-content: center; padding-top: 50px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); width: 300px; }
        input { width: 100%; margin-bottom: 10px; padding: 8px; box-sizing: border-box; }
        input[type="submit"] { background: #007bff; color: white; border: none; cursor: pointer; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h2>Créer un compte FTP</h2>
        <form method="POST">
            <input type="text" name="user" placeholder="Nom d'utilisateur" required>
            <input type="password" name="pass" placeholder="Mot de passe" required>
            <input type="submit" value="S'inscrire">
        </form>
        <p class="{{ 'success' if 'Succès' in msg else 'error' }}">{{ msg }}</p>
    </div>
</body>
</html>
"""


@app.route("/", methods=["GET", "POST"])
def register():
    message = ""
    if request.method == "POST":
        user = request.form.get("user")
        password = request.form.get("pass")

        # Commande SSH pour créer l'utilisateur à distance
        # -o StrictHostKeyChecking=no évite la question de confirmation manuelle
        cmd = f"ssh -o StrictHostKeyChecking=no root@120.0.37.5 'adduser -D {user} && echo {user}:{password} | chpasswd'"

        ret = os.system(cmd)
        if ret == 0:
            message = f"✅ Succès : Utilisateur {user} créé !"
        else:
            message = "❌ Erreur : Impossible de créer le compte."

    return render_template_string(HTML_PAGE, msg=message)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
