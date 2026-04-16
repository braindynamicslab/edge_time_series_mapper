function fcn_mapper_drawpie(percents,pos,radius,colors, varargin)

p = inputParser;
addParameter(p, "EdgeColor", "none");
addParameter(p, "LineWidth", 1);
parse(p, varargin{:});
EdgeColor = p.Results.EdgeColor;
LineWidth = p.Results.LineWidth;

    points = 40;
    x = pos(1);
    y = pos(2);
    last_t = 0;
    if (length(find(percents))>1)
        for i = 1:length(percents)
            end_t = last_t + percents(i)*points;
            tlist = [last_t ceil(last_t):floor(end_t) end_t];
            xlist = [0 (radius*cos(tlist*2*pi/points)) 0] + x;
            ylist = [0 (radius*sin(tlist*2*pi/points)) 0] + y;
            if isstring(EdgeColor) || ischar(EdgeColor) || all(size(EdgeColor) == [1 3])
                patch(xlist,ylist,colors(i,:), "EdgeColor", EdgeColor, "LineWidth", LineWidth);
            else
                patch(xlist,ylist,colors(i,:), "EdgeColor", EdgeColor{i}, "LineWidth", LineWidth);
            end
            last_t = end_t;
        end
    else
        i=find(percents);
        tlist = [0:points];
        xlist = x+radius*cos(tlist*2*pi/points);
        ylist = y+radius*sin(tlist*2*pi/points);
        if isstring(EdgeColor) || ischar(EdgeColor) || all(size(EdgeColor) == [1 3])
            patch(xlist,ylist,colors(i,:), "EdgeColor", EdgeColor, "LineWidth", LineWidth);
        else
            patch(xlist,ylist,colors(i,:), "EdgeColor", EdgeColor{i}, "LineWidth", LineWidth);
        end
    end
end