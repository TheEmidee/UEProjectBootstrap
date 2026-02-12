import os
import multiprocessing
from lxml import etree

def update_parallel_executor(root):
    pe = root.find(".//{https://www.unrealengine.com/BuildConfiguration}ParallelExecutor")
    if pe is None:
        pe = etree.SubElement(root, "ParallelExecutor")

    mpab = pe.find(".//{https://www.unrealengine.com/BuildConfiguration}MemoryPerActionBytes")
    if mpab is None:
        mpab = etree.SubElement(pe, "MemoryPerActionBytes")
    mpab.text = "0"

    mpc = pe.find(".//{https://www.unrealengine.com/BuildConfiguration}MaxProcessorCount")
    if mpc is None:
        mpc = etree.SubElement(pe, "MaxProcessorCount")
    mpc.text = str(multiprocessing.cpu_count() - 1)

    pcm = pe.find(".//{https://www.unrealengine.com/BuildConfiguration}ProcessorCountMultiplier")
    if pcm is None:
        pcm = etree.SubElement(pe, "ProcessorCountMultiplier")
    pcm.text = "2"

def update_build_configuration(root):
    bc = root.find(".//{https://www.unrealengine.com/BuildConfiguration}BuildConfiguration")
    if bc is None:
        bc = etree.SubElement(root, "BuildConfiguration")

    mpa = bc.find(".//{https://www.unrealengine.com/BuildConfiguration}MaxParallelActions")
    if mpa is None:
        mpa = etree.SubElement(bc, "MaxParallelActions")
    mpa.text = str(multiprocessing.cpu_count() - 1)

    aubae = bc.find(".//{https://www.unrealengine.com/BuildConfiguration}bAllowUBAExecutor")
    if aubae is None:
        aubae = etree.SubElement(bc, "bAllowUBAExecutor")
    aubae.text = "true"

    # Fixup for old code that would add this node by mistake
    mpc = bc.find(".//{https://www.unrealengine.com/BuildConfiguration}MaxProcessorCount")
    if mpc is not None:
        bc.remove(mpc)

def update_horde(root):
    h = root.find(".//{https://www.unrealengine.com/BuildConfiguration}Horde")
    if h is None:
        h = etree.SubElement(root, "Horde")

    s = h.find(".//{https://www.unrealengine.com/BuildConfiguration}Server")
    if s is None:
        s = etree.SubElement(h, "Server")
    s.text = "http://hordeserver:13340"

    wp = h.find(".//{https://www.unrealengine.com/BuildConfiguration}WindowsPool")
    if wp is None:
        wp = etree.SubElement(h, "WindowsPool")
    wp.text = "Win-UE5"

    uba = root.find(".//{https://www.unrealengine.com/BuildConfiguration}UnrealBuildAccelerator")
    if uba is None:
        uba = etree.SubElement(root, "UnrealBuildAccelerator")

    lv = uba.find(".//{https://www.unrealengine.com/BuildConfiguration}bLaunchVisualizer")
    if lv is None:
        lv = etree.SubElement(uba, "bLaunchVisualizer")
    lv.text = "false"

def update_unreal_config(file_path, processor_count):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    if not os.path.exists(file_path):
        root = etree.Element("Configuration", xmlns="https://www.unrealengine.com/BuildConfiguration")
        tree = etree.ElementTree(root)
    else:
        parser = etree.XMLParser(remove_blank_text=True)
        tree = etree.parse(file_path, parser)
        root = tree.getroot()

    update_parallel_executor(root)
    update_build_configuration(root)
    update_horde(root)
    
    tree.write(file_path, encoding="utf-8", xml_declaration=True, pretty_print=True)
    print(f"Updated BuildConfiguration.xml at {file_path}")


path = os.path.expandvars(r"%AppData%\Unreal Engine\UnrealBuildTool\BuildConfiguration.xml")
update_unreal_config(path, multiprocessing.cpu_count())