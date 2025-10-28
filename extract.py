import tarfile
import os
from csv import writer
from lxml import etree
from alto import parse_file  # from alto-xml library

#archive_path = "dertag_1900-1902.tar.gz"
#file = "dertagcopy/1901/02/01/01/fulltext/3074409X_1901-02-01_000_27_H_1_009.xml"


TEXTBLOCK_SELECTOR = ".//alto:TextBlock"
TEXTLINE_SELECTOR = "./alto:TextLine/alto:String"
PRINT_SPACE_SELECTOR = ".//alto:PrintSpace"
GRAPHICS_SELECTOR = ".//alto:GraphicalElement"
ILLUSTRATION_SELECTOR = ".//alto:Illustration"

ALTO_NAMESPACE = "http://www.loc.gov/standards/alto/ns-v4#"
NS = {"alto": ALTO_NAMESPACE}



TITLE_MARKERS = ["Dr.", "Professor", "Prof.", "Dr", "Prof", "Profesſor", "Profeſsor", "Profeſſor", "Doktor"]
N_TEXTLINES_THRESHOLD = 3
LENGTH_THRESHOLD = 90
MIN_LENGTH = 10

DATA_FOLDER = "archives"
OUTPUT_FILENAME = "titles.csv"
OUTPUT_HEADERS = ["file", "title_str", "graph_part", "graph_elements_count"]


def get_graphics_share(root):
    print_space = root.find(PRINT_SPACE_SELECTOR, namespaces = NS)
    print_space_size = get_element_size(print_space)
    graph_elements = get_graphical_elements(root)
    graph_sizes = 0
    for g in graph_elements:
        gr_size = get_element_size(g)
        graph_sizes += gr_size
    share = graph_sizes / print_space_size
    return (share, len(graph_elements))

def get_element_size(el):
    return int(el.get("WIDTH")) * int(el.get("HEIGHT"))

def get_graphical_elements(el):
    return el.findall(GRAPHICS_SELECTOR, namespaces = NS) + el.findall(ILLUSTRATION_SELECTOR, namespaces = NS)


def title_string(el):
    text_lines = el.findall(TEXTLINE_SELECTOR, namespaces = NS)
    if len(text_lines) <= N_TEXTLINES_THRESHOLD:
        #print(f"Found {len(text_lines)} lines")
        words = [tl.get("CONTENT") for tl in text_lines if tl.get("CONTENT")]    
        content = " ".join(words)
        #print(content)
        if len(content) <= LENGTH_THRESHOLD and len(content) >= MIN_LENGTH:
            for w in words:
                if w in TITLE_MARKERS:
                    return content.replace("ſ", "s")

test = False
if test:
    tree = etree.parse("/home/pavlo/side_projects/hackathon/test_number.xml")
    root = tree.getroot()
    print(get_graphics_share(root))
    textblocks = root.findall(TEXTBLOCK_SELECTOR, namespaces = NS)
    for element in textblocks:
        ts = title_string(element)
        if ts:
            print(ts)

if not test:
    files = [
        name for name in os.listdir(DATA_FOLDER)
        if os.path.isfile(os.path.join(DATA_FOLDER, name))
    ]
    out_file = open(OUTPUT_FILENAME, "w")
    out_file_writer = writer(out_file)
    out_file_writer.writerow(OUTPUT_HEADERS)
    for archive_file in files:
        print(archive_file)
        archive_path = os.path.join(DATA_FOLDER, archive_file)
        with tarfile.open(archive_path, "r:gz") as tar:
            for member in tar.getmembers():
                    tree = None
                    if member.name.endswith(".xml"):
                        found = True
                        try:
                            with tar.extractfile(member.name) as file_obj:
                                tree = etree.parse(file_obj)
                                root = tree.getroot()
                                #print(root)
                                #print(root.tag)
                                #xml_bytes = file_obj.read()
                        except Exception:
                            print("not found")
                            found = False
                        if found:
                            ns = {"alto": root.nsmap.get(None, "http://www.loc.gov/standards/alto/ns-v4#")}
                            textblocks = root.findall(TEXTBLOCK_SELECTOR, namespaces = NS)
                            #results = tree.xpath(XPATH)
                            # print the matching elements
                            for element in textblocks:
                                ts = title_string(element)
                                if ts:
                                    share, n = get_graphics_share(root)
                                    out_file_writer.writerow([member.name, ts, share, n])
    out_file.close()

