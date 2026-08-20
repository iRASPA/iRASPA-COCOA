# iRASPA-COCOA

iRASPA is a visualization package (with editing capabilities) aimed at material science. Examples of materials are metals, metal-oxides, ceramics, biomaterials, zeolites, clays, and metal-organic frameworks. iRASPA is exclusively for macOS and as such can leverage the latest visualization technologies with stunning performance. iRASPA extensively utilizes GPU computing. For example, void-fractions and surface areas can be computed in a fraction of a second for small/medium structures and in a few seconds for very large unit cells. It can handle large structures (hundreds of thousands of atoms), including ambient occlusion, with high frame rates.

Via iCloud, iRASPA has access to the CoRE Metal-Organic Frameworks database containing approximately 8000 structures. All the structures can be screened (in real-time) using user-defined predicates. The cloud structures can be queried for surface areas, void fraction, and other pore structure properties.

Main features of iRASPA are:
* structure creation and editing,
* creating high-quality pictures and movies,
* ambient occlusion and high-dynamic range rendering,
* collage of structures,
* (transparent) adsorption surfaces,
* text-annotation,
* primitives like cylinders, spheres, and polygonal prisms.
* cell replicas and supercells,
* symmetry operations like space group and primitive cell detection,
* screening of structures using user-defined predicates,
* GPU-computation of void-fraction and surface areas in a matter of seconds.

iCloud structure databases:
* CoRE Metal-Organic Framework database,
* IZA zeolite structures.

Input formats:
* CIF,
* mmCIF,
* PDB,
* XYZ.
* VASP POSCAR/CONTCAR/XDATCAR.

Output:
* CIF-, mmCIF-, PDB-, POSCAR-, or XYZ-files for structures,
* 8/16 bits, RGB/CMYK, loss-less TIFF for pictures,
* mp4 (h264) for movies.

## Building from source

The structure databases in `iRASPA/StructureDatabases` and the bundled Python static libraries in `PythonKit` are stored with [Git LFS](https://git-lfs.com). Install the LFS filters before cloning, otherwise those files arrive as small text pointers instead of real data and the resulting build ships an empty Gallery:

```
git lfs install
git clone https://github.com/iRASPA/iRASPA-COCOA.git
```

If you already cloned without Git LFS installed, fetch the real content with:

```
git lfs install
git lfs pull
```

The `Verify Git LFS Resources` build phase stops the build with an explicit message if any of these files is still an unresolved pointer.

![](https://raw.githubusercontent.com/iRASPA/iRASPA-COCOA/master/iRASPA/ScreenshotMac.png)
*Screenshot of iRASPA*
