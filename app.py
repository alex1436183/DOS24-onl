from flask import Flask, render_template, request, redirect, url_for
import psycopg2
import psycopg2.extras
import os
import time

app = Flask(__name__)

def get_db_connection():
    retries = 5
    for i in range(retries):
        try:
            conn = psycopg2.connect(
                dbname=os.getenv("DB_NAME", "instructions"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "postgres"),
                host=os.getenv("DB_HOST", "localhost"),
                port=os.getenv("DB_PORT", 5432)
            )
            return conn
        except psycopg2.OperationalError as e:
            if i < retries - 1:
                print(f"Ошибка подключения к базе данных: {e}, повторная попытка через 5 секунд...")
                time.sleep(5)
            else:
                print(f"Ошибка подключения к базе данных: {e}, исчерпаны все попытки.")
                raise

def init_db():
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            c.execute('''CREATE TABLE IF NOT EXISTS sections (
                id SERIAL PRIMARY KEY,
                name TEXT UNIQUE NOT NULL
            )''')
            c.execute('''CREATE TABLE IF NOT EXISTS instructions (
                id SERIAL PRIMARY KEY,
                section_id INTEGER REFERENCES sections(id) ON DELETE CASCADE,
                title TEXT NOT NULL,
                content TEXT NOT NULL
            )''')
    conn.close()

@app.route('/')
def index():
    conn = get_db_connection()
    with conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as c:
            c.execute("SELECT * FROM sections")
            sections = c.fetchall()
    conn.close()
    return render_template('index.html', sections=sections)

@app.route('/add_section', methods=['POST'])
def add_section():
    section_name = request.form['section_name']
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            try:
                c.execute("INSERT INTO sections (name) VALUES (%s)", (section_name,))
            except psycopg2.IntegrityError:
                conn.rollback()
                return "Ошибка: Раздел с таким именем уже существует."
    conn.close()
    return redirect(url_for('index'))

@app.route('/edit_section/<int:section_id>', methods=['POST'])
def edit_section(section_id):
    new_name = request.form['new_name']
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            try:
                c.execute("UPDATE sections SET name = %s WHERE id = %s", (new_name, section_id))
            except psycopg2.IntegrityError:
                conn.rollback()
                return "Ошибка: Раздел с этим именем уже существует."
    conn.close()
    return redirect(url_for('index'))

@app.route('/delete_section/<int:section_id>', methods=['POST'])
def delete_section(section_id):
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            c.execute("DELETE FROM sections WHERE id = %s", (section_id,))
    conn.close()
    return redirect(url_for('index'))

@app.route('/section/<int:section_id>')
def section(section_id):
    conn = get_db_connection()
    with conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as c:
            c.execute("SELECT * FROM sections WHERE id = %s", (section_id,))
            section = c.fetchone()
            if not section:
                return "Ошибка: Раздел не найден."
            c.execute("SELECT * FROM instructions WHERE section_id = %s", (section_id,))
            instructions = c.fetchall()
    conn.close()
    return render_template('section.html', section=section, instructions=instructions)

@app.route('/add_instruction/<int:section_id>', methods=['POST'])
def add_instruction(section_id):
    title = request.form['title']
    content = request.form['content']
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            try:
                c.execute("INSERT INTO instructions (section_id, title, content) VALUES (%s, %s, %s)",
                          (section_id, title, content))
            except psycopg2.Error:
                conn.rollback()
                return "Ошибка: Не удалось добавить инструкцию."
    conn.close()
    return redirect(url_for('section', section_id=section_id))

@app.route('/delete_instruction/<int:instruction_id>/<int:section_id>', methods=['POST'])
def delete_instruction(instruction_id, section_id):
    conn = get_db_connection()
    with conn:
        with conn.cursor() as c:
            c.execute("DELETE FROM instructions WHERE id = %s", (instruction_id,))
    conn.close()
    return redirect(url_for('section', section_id=section_id))

@app.route('/edit_instruction/<int:instruction_id>', methods=['GET', 'POST'])
def edit_instruction(instruction_id):
    conn = get_db_connection()
    with conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as c:
            c.execute("SELECT * FROM instructions WHERE id = %s", (instruction_id,))
            instruction = c.fetchone()
            if not instruction:
                return "Инструкция не найдена."

            if request.method == 'POST':
                title = request.form['title']
                content = request.form['content']
                c.execute("UPDATE instructions SET title = %s, content = %s WHERE id = %s",
                          (title, content, instruction_id))
                conn.commit()
                return redirect(url_for('section', section_id=instruction['section_id']))

    conn.close()
    return render_template('edit_instruction.html', instruction=instruction)

if __name__ == '__main__':
    init_db()
    app.run(debug=False, host="0.0.0.0")
