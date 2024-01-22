#+
#+ Function that hides several elements with the same tag
#+
#+ Parameters:
#+ tagname  = Name of tag (Ex: Table, Label).
#+ property = Property to be changed(Ex: hidden, value, name)
#+ value    = New value of tag
#+
function setPropertyByTag(tagname string, property string, value string) returns()

    define XPquery string,
		window ui.Window,
        node om.DomNode,
        list om.NodeList,
        nodo om.DomNode,
		i smallint

    try
        let XPquery = "//*[@tag='", tagname clipped, "']"

        let window = ui.Window.getCurrent()
        let node = window.getNode()
        let list = node.selectByPath(XPquery)

        for i = 1 to list.getLength()
            let nodo = list.item(i)
            call nodo.setAttribute(property, value)
        end for
    catch
        call error("The property could not be set " || property || " with the value "|| value)
    end try
    
end function
