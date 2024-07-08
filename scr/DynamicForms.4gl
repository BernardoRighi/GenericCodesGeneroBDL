import util

#+
#+ 
#+
public function teste() returns()

    call criar_formulario_tabela('users')

end function

FUNCTION criar_formulario_tabela(l_tabela string)
    DEFINE column_count INTEGER = 10
    DEFINE page_mode BOOLEAN = false
    DEFINE page_size INTEGER = 6
    DEFINE d ui.Dialog
    DEFINE fields DYNAMIC ARRAY OF RECORD
        name STRING,
        type STRING
    END RECORD
    
    DEFINE i INTEGER
    DEFINE event STRING
    
    DEFINE page INTEGER
    DEFINE idx INTEGER
    DEFINE value INTEGER
    
    DEFINE page_count INTEGER
    DEFINE min_field, max_field INTEGER

    define l_json util.JSONObject
    define l_json_length int

    call retorna_json_fields(l_tabela) returning l_json

    let  l_json_length = l_json.getLength()

    IF page_mode THEN
        LET page_count = ((l_json_length-1) / page_size)+1
    ELSE
        LET page_count = 1
        LET page_size = l_json_length
    END IF

    OPEN WINDOW dynamic_input WITH 1 ROWS, 1 COLUMNS ATTRIBUTES(TEXT=l_tabela)

    LET page = 1
    
    WHILE TRUE
        -- Determine field range
        LET min_field = (page-1) * page_size +1
        LET max_field = page * page_size
        IF max_field > l_json_length THEN
            LET max_field = l_json_length
        END IF
        
        CALL create_form(l_json,column_count, page)

        -- Define field list
        CALL fields.clear()
        FOR i = min_field TO max_field
            LET fields[i-min_field+1].name = l_json.name(i)
            LET fields[i-min_field+1].type = l_json.get(l_json.name(i))
        END FOR

        -- Build dialog
        LET d = ui.Dialog.createInputByName(fields)
        CALL d.addTrigger("ON ACTION close")
        IF page_mode THEN
            FOR i =  1 TO page_count
                CALL d.addTrigger(SFMT("ON ACTION page%1", i USING "&&&"))
            END FOR
        END IF
        
        -- Add events
        WHILE TRUE  
            LET event = d.nextEvent()
            CASE 
                WHEN event = "ON ACTION close"
                    LET int_flag = TRUE
                    EXIT WHILE

                -- User changes value in field
                WHEN event MATCHES "ON CHANGE"
                    LET idx = event.subString(14,event.getLength())
                    LET value = d.getFieldValue(l_json.name(idx))
                    MESSAGE SFMT("Field qty%1 changed, new value is %2", idx,value)

                -- In page moade, user selects another page
                WHEN event MATCHES "ON ACTION page*" 
                    LET page = event.subString(15, event.getLength())
                    EXIT WHILE
            END CASE
        END WHILE
        CALL d.close()

        IF int_flag THEN
            EXIT WHILE
        END IF
        
    END WHILE
    LET int_flag = 0
    CLOSE WINDOW dynamic_input
END FUNCTION



FUNCTION create_form(l_json , column_count, page )
define l_json util.JSONObject
DEFINE column_count INTEGER
DEFINE page INTEGER
define l_json_length int

DEFINE x, y, idx INTEGER
DEFINE row_size INTEGER

DEFINE w ui.Window
DEFINE f ui.Form
DEFINE form_node, vbox_node, hbox_node, group_node, grid_node, label_node, form_field_node, widget_node om.DomNode
DEFINE width, height INTEGER

    let l_json_length = l_json.getLength()
    
    LET w = ui.Window.getCurrent()
    LET f = w.createForm("dynamic_input")
    
    LET form_node = f.getNode()

    --VBox
    LET vbox_node = form_node.createChild("VBox")
    CALL vbox_node.setAttribute("name","vbox")
        LET row_size = ((l_json_length-1) / column_count) + 1
    LET idx = (page-1)*l_json_length
    LET height = 0
    LET width = 0
    FOR y = 1 TO row_size
        LET height = height + 2
        
        LET hbox_node = vbox_node.createChild("HBox")
        FOR x = 1 TO column_count
            IF x = 1 THEN -- Only need to calc once
                LET width = width + 10
            END IF
            LET idx = idx + 1
            
            --Group
            LET group_node = hbox_node.createChild("Group")
            --Grid
            LET grid_node = group_node.createChild("Grid")
            IF idx <= l_json_length THEN
                --Fields
                LET label_node = grid_node.createChild("Label")
                CALL label_node.setAttribute("posX",1)
                CALL label_node.setAttribute("posY",1)
                CALL label_node.setAttribute("text", l_json.name(idx))

                LET form_field_node = grid_node.createChild("FormField")
                CALL form_field_node.setAttribute("colName",l_json.name(idx))
                CALL form_field_node.setAttribute("name",l_json.name(idx))
                CALL form_field_node.setAttribute("tabIndex",idx)

                LET widget_node = form_field_node.createChild(IIF(l_json.get(l_json.name(idx)) = 'DATE', 'DateEdit', "Edit"))
                CALL widget_node.setAttribute("posX",1)
                CALL widget_node.setAttribute("posY",2)
                CALL widget_node.setAttribute("width",10)
                CALL widget_node.setAttribute("height","1")
            END IF
            
        END FOR
    END FOR
    CALL form_node.setAttribute("width",width)
    CALL form_node.setAttribute("height",height)
    
END FUNCTION

#+
#+ 
#+
function retorna_json_fields(l_tabela string) returns(util.JSONObject)

    define l_sql base.SqlHandle
    define l_i integer

    define l_json util.JSONObject

    call base.SqlHandle.create() returning l_sql

    call l_sql.prepare(sfmt('select * from %1 where 0=1', l_tabela))
    call l_sql.open()
    call l_sql.fetch()

    call util.JSONObject.create() returning l_json
    
    for l_i = 1 to l_sql.getResultCount()
        call l_json.put(l_sql.getResultName(l_i), l_sql.getResultType(l_i))
    end for

    return l_json

end function
