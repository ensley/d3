var width = 720,
	height = 720,
	outerRadius = Math.min(width, height) / 2 - 10,
	innerRadius = outerRadius - 24,
	textWidth = 300;


var layout = d3.chord()
	.padAngle(0.03)
	.sortSubgroups(d3.descending)
	.sortChords(d3.ascending);

var arc = d3.arc()
	.innerRadius(innerRadius)
	.outerRadius(outerRadius);

var ribbon = d3.ribbon()
	.radius(innerRadius);

var svg = d3.select('body').append('svg')
		.attr('width', width+textWidth)
		.attr('height', height)

svg.append('g')
		.attr('class', 'label')
	.append('text')
		.attr('class', 'team')
		.attr('x', width+textWidth)
		.attr('y', 0)
		.text('Pittsburgh Penguins')

svg = svg.append('g')
		.attr('id', 'circle')
		.attr('transform', 'translate('+width/2+','+height/2+')');

svg.append('circle')
	.attr('r', outerRadius);



d3.queue()
	.defer(d3.csv, 'data/roster.csv')
	.defer(d3.json, 'data/matrix.json')
	.await(ready);


function ready(error, roster, matrix) {
	if (error) throw error;

	var chords = layout(matrix);

	console.log(chords.groups);

	var groups = svg.selectAll('.group')
		.data(chords.groups)
		.enter().append('g')
		.attr('class', 'group')
		.on('mouseover', mouseover);

	groups.append('title')
		.text(function(d, i) {
			return roster[i].first + ' ' + roster[i].last + ': ' + d.value + ' assists';
		});

	var groupPaths = groups.append('path')
		.attr('id', function(d, i) { return 'group'+i; })
		.attr('class', 'player')
		.attr('d', arc)
		.style('fill', function(d, i) { console.log(roster[i].color); return roster[i].color; });

	var groupText = groups.append('text')
		.attr('x', 6)
		.attr('dx', 3)
		.attr('dy', 15);

	groupText.append('textPath')
		.attr('xlink:href', function(d, i) { return '#group' + i; })
		.text(function(d, i) { return roster[i].last; });

	groupText.filter(function(d, i) {
		return groupPaths._groups[0][i].getTotalLength() / 2 - 25 < this.getComputedTextLength();
	}).remove();

	var ribbons = svg.selectAll('.ribbon')
		.data(chords)
		.enter().append('path')
		.attr('class', 'ribbon')
		.style('fill', function(d) { return roster[d.source.index].color; })
		.attr('d', ribbon);

	ribbons.append('title')
		.text(function(d) {
			return roster[d.source.index].first + ' ' + roster[d.source.index].last
				+ ' → ' + roster[d.target.index].first + ' ' + roster[d.target.index].last
				+ ': ' + d.source.value + ' assists'
				+ '\n' + roster[d.target.index].first + ' ' + roster[d.target.index].last
				+ ' → ' + roster[d.source.index].first + ' ' + roster[d.source.index].last
				+ ': ' + d.target.value + ' assists'
		});

	d3.selectAll('.label').append('text')
		.attr('class', 'total')
		.attr('x', width+textWidth)
		.attr('y', '50')
		.text('Total assists: '+d3.sum(matrix, function(row) {
			return d3.sum(row);
		}));

	function mouseover(d, i) {
		ribbons.classed('fade', function(p) {
			return p.source.index != i
				&& p.target.index != i;
		});
	}
}