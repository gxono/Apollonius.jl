document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".docs-example").forEach(example => {
        const source = example.querySelector("pre");
        if (!source) return;

        const details = document.createElement("details");
        const summary = document.createElement("summary");

        summary.textContent = "See script";

        example.insertBefore(details, source);
        details.appendChild(summary);
        details.appendChild(source);
    });
});