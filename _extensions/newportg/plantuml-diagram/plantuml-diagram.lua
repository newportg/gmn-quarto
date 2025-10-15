-- PlantUML Diagram Extension for Pandoc
-- This extension processes code blocks with the class "plantuml"
-- It generates SVG diagrams using PlantUML and includes them in the output document  

-- check if file exists
function FileExists(filename)

   local isPresent = true
   -- Opens a file
   f = io.open(filename)

   -- if file is not present, f will be nil
   if not f then
      isPresent = false
   else
      -- close the file  
      f:close()
   end

   -- return status
   return isPresent
end

function CodeBlock(elem)
  if elem.classes:includes("plantuml") then
    local diagram = tostring(elem.text)
    local inputfile
    local outputfile

    if elem.attributes["pumlfile"] ~= nil then
      local attributes = elem.attributes["pumlfile"] 
      inputfile = tostring(attributes) .. ".puml"
      outputfile = tostring(attributes) .. ".svg"

      local exists = FileExists(inputfile)
      print( "Exists : " .. tostring(exists) )
      if( not exists ) then
        diagram = "@startuml\n: Invalid Puml File; \n@enduml"
      
        -- Write the diagram to the file
        local file = io.open(inputfile, "w")
        file:write(diagram)
        file:close()
      end
    else
      inputfile = pandoc.sha1(diagram) .. ".puml"
      outputfile = pandoc.sha1(diagram) .. ".svg"

      if diagram:find("@startuml") == nil then
        diagram = "@startuml\n: Invalid Puml File; \n@enduml"
      end
      -- Write the diagram to the file
      local file = io.open(inputfile, "w")
      file:write(diagram)
      file:close()
    end

    print("===START DIAGRAM===")
    print(tostring(elem.text))
    print("=== END DIAGRAM ===")
    print( inputfile )
    print( outputfile )

    -- Use the file with PlantUML
    os.execute("plantuml -tsvg " .. inputfile .. " -o .")

    -- Create an Attr object with empty ID, classes, and key-value pairs  
    local attr = pandoc.Attr("", {}, {})  
    return pandoc.Para{pandoc.Image("PlantUML Diagram", outputfile)}
  end
end
