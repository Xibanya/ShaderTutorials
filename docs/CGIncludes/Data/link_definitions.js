var xmlhttp = new XMLHttpRequest();
xmlhttp.addEventListener("load", MakeLinks);
xmlhttp.addEventListener("readystatechange", MakeLinks);
xmlhttp.addEventListener("DOMContentLoaded", MakeLinks);
xmlhttp.open("GET", "https://xibanya.github.io/ShaderTutorials/CGIncludes/Data/Definitions.json", true);
xmlhttp.send();

function MakeLinks(evt)
{
    var definitions = JSON.parse(this.responseText);
    definitions.forEach(function(shaderField)
    {
            var page = "https://xibanya.github.io/ShaderTutorials/CGIncludes/" + shaderField.Include + ".html";
            var linkString = page + "#" + shaderField.Field;
            var newTag = "<a href=\"" + linkString + "\">" + shaderField.Field + "</a>";
            findAndReplace(shaderField.Field, newTag, document.getElementById("test_body"));
    });
}

//adapted from https://j11y.io/snippets/find-and-replace-text-with-javascript/
function findAndReplace(searchText, replacement, searchNode) {
    if (!searchText || typeof replacement === 'undefined') {
        // Throw error here if you want...
        return;
    }
    var regex = typeof searchText === 'string' ?
                new RegExp(`\\b${searchText}\\b`, 'g') : searchText,
        childNodes = (searchNode || document.body).childNodes,
        cnLength = childNodes.length,
        excludes = 'html,head,style,title,link,meta,script,object,iframe';
    while (cnLength--) {
        var currentNode = childNodes[cnLength];
        if (currentNode.nodeType === 1 &&
            (excludes + ',').indexOf(currentNode.nodeName.toLowerCase() + ',') === -1) {
            arguments.callee(searchText, replacement, currentNode);
        }
        if (currentNode.nodeType !== 3 || !regex.test(currentNode.data) ) {
            continue;
        }
        var parent = currentNode.parentNode,
            frag = (function(){
                var html = currentNode.data.replace(regex, replacement),
                    wrap = document.createElement('div'),
                    frag = document.createDocumentFragment();
                wrap.innerHTML = html;
                while (wrap.firstChild) {
                    frag.appendChild(wrap.firstChild);
                }
                return frag;
            })();
        parent.insertBefore(frag, currentNode);
        parent.removeChild(currentNode);
    }
}
