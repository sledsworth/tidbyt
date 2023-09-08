"""
Applet: Website Status
Summary: Displays website status
Description: Displays whether a website is up or down based on a couple different choices: 1. A URL returns a status of 200. 2. A CSS selector is found on the page.
Author: sledsworth
"""

load("html.star", "html")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_WEBSITE_URL = "https://thetraveler.news"
DEFAULT_COLOR = "#ffffff"

ICON_SELECTORS = [
    'head link[rel="icon"]',
    'head link[rel="alternate icon"]',
    'head link[rel="shortcut icon"]',
    'head link[rel="apple-touch-icon"]',
]

def getImage(imageBody, bgColor):
    if (imageBody):
        return render.Circle(
            child = render.Image(src = imageBody, width = 18, height = 18),
            diameter = 20,
            color = bgColor,
        )
    return None

def getStatusText(isUp):
    colors = [
        "#00ff00",
        "#00ee00",
        "#00dd00",
        "#00cc00",
        "#00bb00",
    ] if isUp else [
        "#ff0000",
        "#ee0000",
        "#dd0000",
        "#cc0000",
        "#bb0000",
    ]
    colorsReversed = []
    text = "Up" if isUp else "Down"
    circleAnimations = []
    textAnimations = []

    for color in colors:
        colorsReversed.insert(0, color)
        circleAnimations.append(render.Circle(
            diameter = 5,
            color = color,
        ))
        textAnimations.append(render.Text(
            text,
            color = color,
            font = "CG-pixel-3x5-mono",
        ))

    for color in colorsReversed:
        circleAnimations.append(render.Circle(
            diameter = 5,
            color = color,
        ))
        textAnimations.append(render.Text(
            text,
            color = color,
            font = "CG-pixel-3x5-mono",
        ))

    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Animation(
                children = circleAnimations,
            ),
            render.Box(height = 1, width = 2),
            render.Animation(
                children = textAnimations,
            ),
        ],
    )

def main(config):
    url = config.str("url", DEFAULT_WEBSITE_URL)
    iconLocation = config.str("icon")
    textColor = config.str("text-color", DEFAULT_COLOR)
    iconBackgroundColor = config.str("icon-bg-color", DEFAULT_COLOR)
    isUpQuery = config.str("up-query", False)

    page = http.get(url)
    pageBody = page.body()

    dom = html(pageBody)
    pageTitle = dom.find("head title").text()

    isUp = page.status_code == 200
    print(isUpQuery)
    if isUpQuery:
        isUpElements = dom.find(isUpQuery)
        isUp = isUpElements.len() > 0

    print(isUp)
    if not iconLocation:
        for iconSelector in ICON_SELECTORS:
            iconElement = dom.find(iconSelector)
            if iconElement and iconElement.attr("href"):
                if iconElement.attr("href").endswith(".png"):
                    iconLocation = iconElement.attr("href")
                    break

    if iconLocation:
        image = http.get(url + iconLocation)
        imageBody = image.body()
    else:
        imageBody = False

    return render.Root(
        delay = 75,
        max_age = 60,
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render.Box(width = 1, height = 1),
                getImage(imageBody, iconBackgroundColor),
                render.Box(width = 2, height = 1),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Marquee(
                            width = 40,
                            child = render.Text(
                                pageTitle,
                                color = textColor,
                            ),
                        ),
                        render.Box(height = 2),
                        getStatusText(isUp),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "url",
                name = "Website URL",
                desc = "URL of the website you would like to know is up.",
                icon = "bookmark",
            ),
            schema.Text(
                id = "up-query",
                name = "CSS Query",
                desc = "The search query to run to identify if the site is working properly. If not set we assume a status of 200 returned from the HTTP GET request means the site is up.",
                icon = "magnifyingGlass",
            ),
            schema.Color(
                id = "text-color",
                name = "Text Color",
                desc = "Color of the text.",
                icon = "brush",
                default = "#ffffff",
            ),
            schema.Color(
                id = "icon-bg-color",
                name = "Icon Background Color",
                desc = "Icon background color.",
                icon = "brush",
                default = "#ffffff",
            ),
            schema.Text(
                id = "icon",
                name = "Icon Location",
                desc = "Location of icon to display, relative to root domain.",
                icon = "icons",
            ),
        ],
    )
