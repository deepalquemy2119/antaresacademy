from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, session

app = Flask(__name__)
app.secret_key = 'JadenKugo2119$&?'



@app.route('/')
def base():
    fecha_completa = datetime.now().strftime("%Y")
    return render_template("base.html",fecha_completa=fecha_completa)


@app.route("/home")
def home():
    return render_template("home.html")


@app.route('/account')
def account():
    return render_template('account.html')


@app.route('/myknowledge')
def myknowledge():
    return render_template('myknowledge.html')


#__________ route-alumno ________

# - con validacion ALUMNO -
@app.route('/alumno')
def alumno():
    if session.get('rol') != 'alumno':
        return redirect(url_for('acceso_denegado'))
    return render_template('base_alumno.html')


#__________ route-admin _________

# - Con validacion ADMIN -
@app.route('/admin')
def admin():
    if session.get('rol') != 'admin':
        return redirect(url_for('acceso_denegado'))
    return render_template('base_admin.html')


#___________ route-tutor__________

#- con validacion tutor -
@app.route('/tutor')
def tutor():
    if session.get('rol') != 'tutor':
        return redirect(url_for('acceso_denegado'))
    return render_template('base_tutor.html')

#__________ route-403_________
@app.route('/acceso-denegado')
def acceso_denegado():
    return render_template('403.html'), 403



#__________ route-logout________
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

#__________ route-login __________
@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        email = request.form['email']
        clave = request.form['clave']
        user = USUARIOS.get(email)
        if user and user['clave'] == clave:
            session['usuario'] = email
            session['rol'] = user['rol']
            return redirect(url_for(user['rol']))  # redirige a /admin, /alumno o /tutor
        else:
            error = 'Correo o contraseña incorrectos.'
    return render_template('login.html', error=error)



#_____________ router-year__________
@app.context_processor
def inject_fecha():
    hoy = datetime.now()
    return {
        'fecha_completa': hoy.strftime("%d/%m/%Y")  # formato: DD/MM/YYYY
    }

if __name__ == '__main__':
    app.run(debug=True)
