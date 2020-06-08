var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Duke NGS_Workflow",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/malloc3/aq_ngs_workflow/issues' }
      ]
    },

    

      {

        category: "Operation Types",

        contents: [

          
            {
              name: 'Normalization Pooling',
              path: 'operation_types/Normalization_Pooling' + '.md',
              type: "local-md"
            },
          
            {
              name: 'RNA Prep',
              path: 'operation_types/RNA_Prep' + '.md',
              type: "local-md"
            },
          
            {
              name: 'RNA QC',
              path: 'operation_types/RNA_QC' + '.md',
              type: "local-md"
            },
          
            {
              name: 'cDNA QC',
              path: 'operation_types/cDNA_QC' + '.md',
              type: "local-md"
            },
          

        ]

      },

    

    

      {

        category: "Libraries",

        contents: [

          
            {
              name: 'CsvDebugLib',
              path: 'libraries/CsvDebugLib' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'DataHelper',
              path: 'libraries/DataHelper' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'KeywordLib',
              path: 'libraries/KeywordLib' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'MiscMethods',
              path: 'libraries/MiscMethods' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'ParseCSV',
              path: 'libraries/ParseCSV' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'TakeMeasurements',
              path: 'libraries/TakeMeasurements' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'WorkflowValidation',
              path: 'libraries/WorkflowValidation' + '.html',
              type: "local-webpage"
            },
          

        ]

    },

    

    
      { category: "Sample Types",
        contents: [
          
            {
              name: 'RNA Sample',
              path: 'sample_types/RNA_Sample'  + '.md',
              type: "local-md"
            },
          
        ]
      },
      { category: "Containers",
        contents: [
          
            {
              name: '96 Well Sample Plate',
              path: 'object_types/96_Well_Sample_Plate'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'Total RNA 96 Well Plate',
              path: 'object_types/Total_RNA_96_Well_Plate'  + '.md',
              type: "local-md"
            },
          
        ]
      }
    

  ]

};
