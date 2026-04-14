%% Test 1: Simple multi-line x-axis labels
clear; close all;

figure('Color','w');
x = 1:5;
y = rand(1,5);

plot(x, y, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
grid on;

% Test different label formats
labels = {
    'Short',
    'Medium',
    'Long label',
    'Very long label',
    ['Fluid intelligence' newline '(PMAT)']  % Two-line label
};

set(gca, 'XTick', x, 'XTickLabel', labels, 'XTickLabelRotation', 45);
xlabel('Different Label Formats');
ylabel('Random Values');
title('Test 1: Direct \n in XTickLabel');