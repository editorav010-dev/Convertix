import gradio as gr
import os
import subprocess
import shutil
import tempfile
import pymupdf

def run_libreoffice_conversion(input_path: str, output_dir: str, output_format: str) -> str:
    user_profile = os.path.join(output_dir, "lo_profile")
    os.makedirs(user_profile, exist_ok=True)

    cmd = [
        "libreoffice",
        "--headless",
        "--invisible",
        "--nologo",
        "--nodefault",
        "--nofirststartwizard",
        f"-env:UserInstallation=file://{user_profile}",
        "--convert-to", output_format,
        "--outdir", output_dir,
        input_path
    ]
    
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
        
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        expected_output = os.path.join(output_dir, f"{base_name}.{output_format}")
        
        if os.path.exists(expected_output):
            return expected_output
            
        for file in os.listdir(output_dir):
            if file.endswith(f".{output_format}"):
                return os.path.join(output_dir, file)
                
        raise Exception("Output file not found after conversion.")
    except Exception as e:
        raise Exception(f"Conversion failed: {str(e)}")

def health_check():
    return "ok"

def convert_document(input_file_path, output_format, pages=""):
    if not input_file_path:
        raise gr.Error("No input file provided")
    
    job_dir = tempfile.mkdtemp()
    supported_formats = ['pdf', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp', 'rtf', 'txt', 'csv']
    try:
        if output_format in supported_formats:
            result_path = run_libreoffice_conversion(input_file_path, job_dir, output_format)
            final_path = os.path.join(tempfile.gettempdir(), os.path.basename(result_path))
            shutil.copy2(result_path, final_path)
            return final_path
        else:
            raise gr.Error(f"Unsupported format: {output_format}")
            
    finally:
        shutil.rmtree(job_dir, ignore_errors=True)

def split_pdf(input_file_path, split_by):
    if not input_file_path:
        raise gr.Error("No input file provided")
        
    try:
        split_by = int(split_by)
    except:
        split_by = 1
        
    job_dir = tempfile.mkdtemp()
    try:
        doc = pymupdf.open(input_file_path)
        total_pages = len(doc)
        
        output_files = []
        for i in range(0, total_pages, split_by):
            end_page = min(i + split_by - 1, total_pages - 1)
            new_doc = pymupdf.Document()
            new_doc.insert_pdf(doc, from_page=i, to_page=end_page)
            
            out_name = f"split_{i+1}_to_{end_page+1}.pdf"
            out_path = os.path.join(job_dir, out_name)
            new_doc.save(out_path)
            new_doc.close()
            output_files.append(out_path)
            
        zip_base_path = os.path.join(tempfile.gettempdir(), "split_pdfs")
        shutil.make_archive(zip_base_path, 'zip', job_dir)
        
        return zip_base_path + ".zip"
        
    finally:
        shutil.rmtree(job_dir, ignore_errors=True)

def image_to_pdf(image_paths):
    if not image_paths:
        raise gr.Error("No images provided")
    
    doc = pymupdf.Document()
    
    for img_path in image_paths:
        try:
            img_doc = pymupdf.open(img_path)
            pdf_bytes = img_doc.convert_to_pdf()
            pdf_doc = pymupdf.open("pdf", pdf_bytes)
            doc.insert_pdf(pdf_doc)
        except Exception as e:
            continue
            
    out_path = os.path.join(tempfile.gettempdir(), "images_to_pdf.pdf")
    doc.save(out_path)
    doc.close()
    return out_path

def greyscale_pdf(input_file_path):
    if not input_file_path:
        raise gr.Error("No input file provided")
    
    doc = pymupdf.open(input_file_path)
    out_doc = pymupdf.Document()
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        pix = page.get_pixmap(colorspace=pymupdf.csGRAY)
        new_page = out_doc.new_page(width=page.rect.width, height=page.rect.height)
        new_page.insert_image(page.rect, pixmap=pix)
        
    out_path = os.path.join(tempfile.gettempdir(), "greyscale.pdf")
    out_doc.save(out_path)
    out_doc.close()
    doc.close()
    return out_path

def merge_pdf(pdf_paths):
    if not pdf_paths or len(pdf_paths) < 2:
        raise gr.Error("Need at least 2 PDFs to merge")
        
    doc = pymupdf.Document()
    
    for pdf_path in pdf_paths:
        try:
            temp_doc = pymupdf.open(pdf_path)
            doc.insert_pdf(temp_doc)
            temp_doc.close()
        except:
            continue
            
    out_path = os.path.join(tempfile.gettempdir(), "merged.pdf")
    doc.save(out_path)
    doc.close()
    return out_path

with gr.Blocks(title="Convertix API") as demo:
    gr.Markdown("# Convertix Backend API")
    
    with gr.Tab("Health"):
        health_btn = gr.Button("Check Health")
        health_out = gr.Textbox(label="Status")
        health_btn.click(health_check, inputs=[], outputs=health_out, api_name="health")
        
    with gr.Tab("Convert Document"):
        conv_in = gr.File(label="Input Document", type="filepath")
        conv_fmt = gr.Dropdown(choices=["pdf", "docx", "xlsx", "pptx", "odt", "ods", "odp", "rtf", "txt", "csv"], label="Target Format")
        conv_pages = gr.Textbox(label="Page (for images)", placeholder="1")
        conv_btn = gr.Button("Convert")
        conv_out = gr.File(label="Output Document")
        conv_btn.click(convert_document, inputs=[conv_in, conv_fmt, conv_pages], outputs=conv_out, api_name="convert")
        
    with gr.Tab("Split PDF"):
        split_in = gr.File(label="Input PDF", type="filepath")
        split_by = gr.Number(label="Pages per split", value=1)
        split_btn = gr.Button("Split")
        split_out = gr.File(label="Output ZIP")
        split_btn.click(split_pdf, inputs=[split_in, split_by], outputs=split_out, api_name="split")

    with gr.Tab("Image to PDF"):
        img_in = gr.File(label="Input Images", type="filepath", file_count="multiple")
        img_btn = gr.Button("Convert to PDF")
        img_out = gr.File(label="Output PDF")
        img_btn.click(image_to_pdf, inputs=img_in, outputs=img_out, api_name="image_to_pdf")
        
    with gr.Tab("Greyscale PDF"):
        grey_in = gr.File(label="Input PDF", type="filepath")
        grey_btn = gr.Button("Make Greyscale")
        grey_out = gr.File(label="Output PDF")
        grey_btn.click(greyscale_pdf, inputs=grey_in, outputs=grey_out, api_name="greyscale_pdf")
        
    with gr.Tab("Merge PDF"):
        merge_in = gr.File(label="Input PDFs", type="filepath", file_count="multiple")
        merge_btn = gr.Button("Merge PDFs")
        merge_out = gr.File(label="Output PDF")
        merge_btn.click(merge_pdf, inputs=merge_in, outputs=merge_out, api_name="merge_pdf")

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
