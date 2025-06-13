from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, session

from markupsafe import Markup



app = Flask(__name__)
app.secret_key = 'JadenKugo2119$&?'



# --------- Decoradores ----------
from functools import wraps
from flask import flash

def login_requerido(rol=None):
    def decorador(f):
        @wraps(f)
        def decorada(*args, **kwargs):
            if 'usuario' not in session:
                flash(Markup('Debes iniciar sesión para acceder. <a href="/register">¿No tienes cuenta? Regístrate</a>'), 'warning')

                return redirect(url_for('login'))
            if rol and session.get('rol') != rol:
                return redirect(url_for('acceso_denegado'))
            return f(*args, **kwargs)
        return decorada
    return decorador





@app.route('/')
@login_requerido('alumno')
@login_requerido('tutor')
@login_requerido('admin')
def base():
    fecha_completa = datetime.now().strftime("%Y")
    return render_template("base.html",fecha_completa=fecha_completa)


@app.route("/home")
@login_requerido('alumno')
@login_requerido('tutor')
@login_requerido('admin')
def home():
    return render_template("home.html")


@app.route('/account')
@login_requerido('alumno')
@login_requerido('tutor')
@login_requerido('admin')
def account():
    return render_template('account.html')


@app.route('/myknowledge')
@login_requerido('alumno')
def myknowledge():
    return render_template('myknowledge.html')


#__________ route-alumno ________

# - con validacion ALUMNO -
@app.route('/alumno')
@login_requerido('alumno')
def alumno():
    if session.get('rol') != 'alumno':
        return redirect(url_for('acceso_denegado'))
    return render_template('base_alumno.html')


#__________ route-admin _________

# - Con validacion ADMIN -
@app.route('/admin')
@login_requerido('admin')
def admin():
    if session.get('rol') != 'admin':
        return redirect(url_for('acceso_denegado'))
    return render_template('base_admin.html')


#___________ route-tutor__________

#- con validacion tutor -
@app.route('/tutor')
@login_requerido('tutor')
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


#__________ route-register __________
@app.route('/register', methods=['GET', 'POST'])
def register():
    error = None
    if request.method == 'POST':
        email = request.form['email']
        clave = request.form['clave']
        rol = request.form['rol']

        if email in USUARIOS:
            error = 'El correo ya está registrado.'
        elif rol not in ['admin', 'alumno', 'tutor']:
            error = 'Rol inválido.'
        else:
            USUARIOS[email] = {'clave': clave, 'rol': rol}
            flash('Registro exitoso. Ahora puedes iniciar sesión.', 'success')
            return redirect(url_for('login'))

    return render_template('register.html', error=error)





#_____________ router-year__________
@app.context_processor
def inject_fecha():
    hoy = datetime.now()
    return {
        'fecha_completa': hoy.strftime("%d/%m/%Y")  # formato: DD/MM/YYYY
    }

if __name__ == '__main__':
    app.run(debug=True)
