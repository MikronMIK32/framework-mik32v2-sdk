# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'HAL MIK32'
copyright = '2023, Mikron'
author = 'Mikron'
release = '0.1'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.autodoc',
    "breathe",
]

templates_path = ['_templates']
exclude_patterns = []

language = 'ru'

primary_domain = 'c'
highlight_language = 'c'

c_id_attributes = [
    "__attribute__",
    "__attribute__((weak))",
]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme' #furo

# https://sphinx-rtd-theme.readthedocs.io/en/latest/configuring.html
html_theme_options = {
    'collapse_navigation' : True, # Если эта функция включена, элементы навигации не расширяются - значки [+] рядом с каждым элементом удалены.
    'sticky_navigation' : True, # Прокручивайте навигацию вместе с основным содержимым страницы по мере ее прокрутки.
    'navigation_depth' : 4, # Максимальная глубина дерева оглавления. Установите значение -1, чтобы разрешить неограниченную глубину.
    'includehidden' : True, # Указывает, включать ли в навигацию скрытые оглавления - то есть все директивы toctree, отмеченные опцией :hidden:.
    'titles_only' : False, # Если эта функция включена, подзаголовки страниц не включаются в навигацию.
    # Miscellaneous options,
    #'analytics_id' : "G-XXXXXXXXXX", # Если указано, на ваших страницах будет включен gtag.js Google Analytics. Установите значение идентификатора, предоставленного вам Google (например, UA-XXXXXXX или G-XXXXXXXX)
    'analytics_anonymize_ip' : False, # Анонимизация IP-адресов посетителей в Google Analytics.
    #'canonical_url' : "mik32.ru",
    'display_version' : True, # Если значение True, номер версии отображается в верхней части боковой панели.
    'logo_only' : False, # Выводите только изображение логотипа, не показывайте название проекта в верхней части боковой панели
    'prev_next_buttons_location' : "None", # Расположение для отображения кнопок Next и Previous. Это может быть bottom, top both , или None.
    'style_external_links' : False, # Добавьте значок рядом с внешними ссылками.
    #'vcs_pageview_mode' : "",
    'style_nav_header_background' : "#c3c6c3", #Изменяет фон области поиска в панели навигации. В качестве значения может использоваться любое свойство фона CSS.
}



html_static_path = ['_static']

html_logo = "logo.png"

html_show_sourcelink = False

html_context = {
    'current_version' : "MIK32",
    'versions' : [["MIK32_V2", "."],], #["Название версии, "ссылка"]
}

breathe_projects = {
    "doxy_file": "../../doxygen/xml",
}

breathe_default_project = "doxy_file"

breathe_domain_by_extension = {
    "h" : "c",
    "c" : "c",
}

breathe_show_define_initializer = False # Выводит значения дефайнов

breathe_show_enumvalue_initializer = False # Выводит значение перечислений

def setup(app):
    app.add_css_file('my_theme.css') # Расширение страницы
