options short circuit 

#+
#+ Function to compare any two arrays
#+
#+ Details: The arrays must be sorted in the same way, and the order of the fields must also be the same.
#+
#+ Parameters:
#+ first_array        = xml of the array created through a { base.TypeInfo.create(array) }
#+ second_array       = xml of the array created through a { base.TypeInfo.create(array) }
#+ compares_size 	  = indicator if the function will validate the number of records in the arrays.
#+ compares_structure = indicator if the function will validate the structure of the two arrays, the name and type of the fields.
#+ compares_values    = indicator if the function will validate the values of the fields in the arrays.
#+
#+ Return:
#+ true if the two arrays are equal, according to parameters
#+ false if validation fails, according to parameters
#+
public function compareArraysAndRecords(first_array om.DomNode, second_array om.DomNode, compares_size boolean, compares_structure boolean, compares_values boolean) returns (boolean)

    define i, j       integer
    define node_aux   om.DomNode
    define node_aux2  om.DomNode

    whenever any error stop

    -- Checking the size of arrays
    if compares_size then
        if first_array.getChildCount() != second_array.getChildCount() then
            return false
        end if
    end if

    -- Check the structure of arrays
    if compares_structure then
        -- Both arrays are record arrays
        if first_array.getChildByIndex(1).getChildCount() > 0 and second_array.getChildByIndex(1).getChildCount() > 0 then
            -- Record arrays with different numbers of fields, so I return
            if first_array.getChildByIndex(1).getChildCount() != second_array.getChildByIndex(1).getChildCount() then
                return false
            end if

            let node_aux = first_array.getChildByIndex(1)
            let node_aux2 = second_array.getChildByIndex(1)

            -- Check all the fields in the record
            for j = 1 to node_aux.getChildCount()
                -- Check that the field names are the same
                if not node_aux.getChildByIndex(j).getAttribute("name").equals(node_aux2.getChildByIndex(j).getAttribute("name")) then
                    return false
                end if

                -- If it's null, it's because it's an internal array, I call the function recursively
                if node_aux.getChildByIndex(j).getAttribute("type") is null and node_aux2.getChildByIndex(j).getAttribute("type") is null then
                    if node_aux.getChildByIndex(j).getChildCount() > 0 then
                        return compareArraysAndRecords(node_aux.getChildByIndex(j), node_aux2.getChildByIndex(j), compares_size, compares_structure, compares_values)
                    end if
                else -- Otherwise I just check the type
                    if not node_aux.getChildByIndex(j).getAttribute("type").equals(node_aux2.getChildByIndex(j).getAttribute("type")) then
                        return false
                    end if
                end if
            end for
        else
            -- The two arrays are not record arrays
            if first_array.getChildByIndex(1).getChildCount() = 0 and second_array.getChildByIndex(1).getChildCount() = 0 then
                if not first_array.getChildByIndex(1).getAttribute("type").equals(second_array.getChildByIndex(1).getAttribute("type")) then
                    return false
                end if
            else -- One of the arrays is records and the other is not, then return
                return false
            end if
        end if
    end if

    -- Check the values
    if compares_values then
        for i = 1 to first_array.getChildCount()
            -- Both arrays are record arrays
            if first_array.getChildByIndex(i).getChildCount() > 0 and second_array.getChildByIndex(i).getChildCount() > 0 then
                let node_aux = first_array.getChildByIndex(i)
                let node_aux2 = second_array.getChildByIndex(i)

                -- Check all the fields in the record
                for j = 1 to node_aux.getChildCount()
                    -- If it's null, it's because it's an internal array, I call the function recursively
                    if node_aux.getChildByIndex(j).getAttribute("value") is null and node_aux2.getChildByIndex(j).getAttribute("value") is null then
                        return compareArraysAndRecords(node_aux.getChildByIndex(j), node_aux2.getChildByIndex(j),  compares_size, compares_structure, compares_values)
                    else -- If I don't check directly
                        if not node_aux.getChildByIndex(j).getAttribute("value").equals(node_aux2.getChildByIndex(j).getAttribute("value")) then
                            return false
                        end if
                    end if
                end for
            else
                -- The two arrays are not record arrays
                if first_array.getChildByIndex(i).getChildCount() = 0 and second_array.getChildByIndex(i).getChildCount() = 0 then
                    if not first_array.getChildByIndex(i).getAttribute("value").equals(second_array.getChildByIndex(i).getAttribute("value")) then
                        return false
                    end if
                else -- One of the arrays is records and the other is not, then return
                    return false
                end if
            end if
        end for
    end if

    return true

end function
