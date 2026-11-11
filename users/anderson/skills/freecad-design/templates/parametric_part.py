"""Parametric FreeCAD part skeleton. Run via execute_code (GUI) or execute_code_headless.

Pattern: every dimension lives in a Params spreadsheet; features read it through
expressions, so editing a cell in FreeCAD rebuilds the part. Primitives + booleans
for simple solids; a constrained sketch + Offset2D/Extrusion for clearance shells.
"""
import FreeCAD as App
import Mesh
import Part

OUT = "/home/anderson/PROJECT"  # snap FreeCAD: non-hidden path under $HOME, never /tmp
NAME = "Part_Name"

if NAME in App.listDocuments():
    App.closeDocument(NAME)
doc = App.newDocument(NAME)

p = doc.addObject("Spreadsheet::Sheet", "Params")
params = [
    # (alias, value_mm, note) — note says where the number came from (measured / estimate / printer-tuned)
    ("Width", 20.0, "Overall width"),
    ("Clear", 0.4, "Gap per side for a sliding fit (printer-tuned)"),
]
for row, (alias, value, note) in enumerate(params, start=1):
    p.set(f"A{row}", alias)
    p.set(f"B{row}", str(value))
    p.set(f"C{row}", note)
    p.setAlias(f"B{row}", alias)
doc.recompute()

box = doc.addObject("Part::Box", "Blank")
box.setExpression("Length", "Params.Width")
box.setExpression(".Placement.Base.x", "-Params.Width / 2")  # placement fields take expressions too

# ... more features; combine with Part::MultiFuse (Shapes=[...]) and Part::Cut (Base/Tool), Refine=True

final = box
doc.recompute()

# ---- Verify before exporting ----
s = final.Shape
bb = s.BoundBox
print("valid", s.isValid(), "solids", len(s.Solids), "volume_mm3", round(s.Volume, 2))
print("bbox", [round(v, 3) for v in (bb.XLength, bb.YLength, bb.ZLength)])


def probe(a, b, axis):
    """Material intervals along segment a->b (axis 0/1/2 = x/y/z): measures holes, walls, floors."""
    edges = s.common(Part.makeLine(App.Vector(*a), App.Vector(*b))).Edges
    return sorted((round(e.Vertexes[0].Point[axis], 3), round(e.Vertexes[-1].Point[axis], 3)) for e in edges)


print("x-intervals at y=z=0:", probe((-50, 0, 0), (50, 0, 0), 0))

# ---- Export ----
doc.saveAs(f"{OUT}/{NAME}.FCStd")
s.exportStep(f"{OUT}/{NAME}.step")
mesh = Mesh.Mesh()
mesh.addFacets(s.tessellate(0.01))
mesh.write(f"{OUT}/{NAME}.stl")
print("mesh solid", mesh.isSolid(), "nonmanifolds", mesh.hasNonManifolds())
