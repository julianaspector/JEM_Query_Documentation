# Workflow diagram for script for management meeting

library(DiagrammeR)
grViz("digraph flowchart {
      # node definitions with substituted label text
      node[fontname = Helvetica, shape = rectangle, style=filled]
      tab1 [label = '@@1']
      tab2 [label = '@@2']
      tab3 [label = '@@3']
      tab4 [label = '@@4', color='#91bfdb']
      tab5 [label = '@@5', color='#fc8d59']
      tab6 [label = '@@6']
      tab7 [label = '@@7']
      tab8 [label = '@@8']
      tab9 [label = '@@9']
      tab10 [label = '@@10', color='#91bfdb']
      tab11 [label = '@@11', color='#fc8d59']
      tab12 [label = '@@12']
      tab13 [label = '@@13', color='#91bfdb']
      tab14 [label = '@@14', color='#fc8d59']
      tab15 [label = '@@15']
      tab16[label = '@@16', color='#91bfdb']
      tab17[label = '@@17', color='#fc8d59']
      tab18[label = '@@18']
      
      # edge definitions with the node IDs
      tab1 -> tab2 -> tab3;
      tab3-> tab4;
      tab3 -> tab5;
      tab4 -> tab13;
      tab4 -> tab14;
      tab14 -> tab6;
      tab13 -> tab15;
      tab6 -> tab7;
      tab7 -> tab8;
      tab5 -> tab9;
      tab9 -> tab10;
      tab9 -> tab11;
      tab11 -> tab12;
      tab12 -> tab6;
      tab15 -> tab16;
      tab15 -> tab17;
      tab16 -> tab18;
      tab17 -> tab7;
      tab18 -> tab8;
      tab10-> tab13;
      tab10 -> tab14;
      }
      
      [1]: 'Obtain list of all water rights records (application IDs) within area of interest'
      [2]: 'Retrieve relevant water right records from eWRIMS database system'
      [3]: 'For each water right record, manually check through eWRIMS documents for previously scanned place of use maps'
      [4]: 'Scanned map available in eWRIMS database'
      [5]: 'Scanned map not available in eWRIMS database'
      [6]: 'Georeference map by PLSS data layers'
      [7]: 'Use scanned map to create place of use polygon'
      [8]: 'Save polygon in geodatabase using appropriate file naming convention'
      [9]: 'Check for application ID in records list of scanned maps on Division of Water Rights server'
      [10]: 'Previously scanned map available on Division of Water Rights server'
      [11]: 'Previously scanned map not available (i.e. available in hard copy format only)'
      [12]: 'Scan map to create digital copy and \\n work with Division of Water Rights staff to append existing eWRIMS record with scanned place of use map'
      [13]: 'Map previously georeferenced'
      [14]: 'Map not previously georeferenced'
      [15]: 'QA/QC georeferenced map and revise map if necessary'
      [16]: 'POU polygon available'
      [17]: 'POU polygon not available'
      [18]: 'QA/QC polygon and revise if necessary'
      ")
