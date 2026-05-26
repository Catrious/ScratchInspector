import zipfile
import json
import tkinter as tk
from tkinter import filedialog, scrolledtext
import os

class ProjectAnalyzer:
    def __init__(self, root):
        self.root = root
        self.root.title("Scratch Inspector")
        self.root.geometry("600x600")
        
        tk.Button(root, text="Analyze Scratch Project (.sb3 / .sb2)", command=self.analyze).pack(pady=15)
        self.text_area = scrolledtext.ScrolledText(root, width=70, height=28)
        self.text_area.pack(pady=10)

    def count_scripts_sb3(self, blocks):
        """Counts top-level stacks starting with a Hat block."""
        count = 0
        for b_data in blocks.values():
            if isinstance(b_data, dict):
                # A script stack top-level block has no parent
                if b_data.get('parent') is None and 'opcode' in b_data:
                    opcode = b_data['opcode']
                    # Any block that triggers execution
                    if 'event_' in opcode or 'control_start_as_clone' in opcode or 'procedures_definition' in opcode:
                        count += 1
        return count

    def analyze(self):
        path = filedialog.askopenfilename(filetypes=[("Scratch Projects", "*.sb3 *.sb2")])
        if not path: return
        
        try:
            with zipfile.ZipFile(path, 'r') as z:
                with z.open('project.json') as f:
                    data = json.load(f)
            
            report = f"AUDIT REPORT: {os.path.basename(path)}\n"
            report += "="*50 + "\n\n"

            # --- SB3 Logic ---
            if 'targets' in data:
                report += "[Format: Scratch 3.0]\n\n"
                for target in data['targets']:
                    name = target.get('name', 'Stage')
                    costumes = len(target.get('costumes', []))
                    scripts = self.count_scripts_sb3(target.get('blocks', {}))
                    
                    report += f"Sprite: {name}\n"
                    report += f"  • Costumes: {costumes}\n"
                    report += f"  • Scripts:  {scripts}\n\n"

            # --- SB2 Logic ---
            elif 'children' in data:
                report += "[Format: Scratch 2.0]\n\n"
                for obj in data.get('children', []):
                    # Only analyze objects with names (sprites)
                    if 'objName' in obj:
                        costumes = len(obj.get('costumes', []))
                        scripts = len(obj.get('scripts', []))
                        
                        report += f"Sprite: {obj['objName']}\n"
                        report += f"  • Costumes: {costumes}\n"
                        report += f"  • Scripts:  {scripts}\n\n"
            
            self.text_area.delete(1.0, tk.END)
            self.text_area.insert(tk.INSERT, report)
            
        except Exception as e:
            self.text_area.delete(1.0, tk.END)
            self.text_area.insert(tk.INSERT, f"Error parsing project: {e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = ProjectAnalyzer(root)
    root.mainloop()
