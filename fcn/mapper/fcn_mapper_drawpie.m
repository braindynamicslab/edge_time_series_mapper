function fcn_mapper_drawpie(percents,pos,radius,colors)
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
            patch(xlist,ylist,colors(i,:), "EdgeColor", "none");
            last_t = end_t;
        end
    else
        i=find(percents);
        tlist = [0:points];
        xlist = x+radius*cos(tlist*2*pi/points);
        ylist = y+radius*sin(tlist*2*pi/points);
        patch(xlist,ylist,colors(i,:), "EdgeColor", "none");
    end
end