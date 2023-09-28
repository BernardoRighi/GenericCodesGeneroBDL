#+
#+ Function to show or hide a screen element
#+
#+ Parameters:
#+ element = Type of element (Ex: Table, Label).
#+ name    = Name of element.
#+ visible = Indicates whether to show or hide the element.
#+
function hideElement(element string, name string, visible integer) returns()

  define XPquery string,
         window ui.Window,
         node  om.DomNode,
         list  om.NodeList

  let XPquery = "//", element, "[@name='", name, "']" 
  let window = ui.Window.getCurrent()
  let node = window.getNode()
  let list = node.selectByPath(XPquery)

  if list.getLength() > 0 then
    let node =  list.item(1)
    call node.setAttribute("hidden", visible)
  end if

end function
